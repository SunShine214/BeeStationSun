import { useBackend } from 'tgui/backend';

import { Window } from '../layouts';
import { MaterialAccessBar } from './Fabrication/MaterialAccessBar';
import { Material } from './Fabrication/Types';

type Data = {
  nanite_cans: NaniteCan[];
  materials: Material[];
};

type NaniteCan = {
  nanites: number;
};

export const HullCrucible = (props) => {
  const { act, data } = useBackend<Data>();
  const { nanite_cans = [], materials = [] } = data;
  return (
    <Window width={300} height={300}>
      <Window.Content>
        {nanite_cans.map((can) => (
          <p key={can}>{can.nanites}</p>
        ))}
        <MaterialAccessBar
          availableMaterials={materials || []}
          onEjectRequested={(material, amount) =>
            act('remove_mat', { ref: material.ref, amount })
          }
        />
      </Window.Content>
    </Window>
  );
};
